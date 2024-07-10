class Game < ApplicationRecord
  has_many :players

  def current_color
    if self.current_turn.even? then WHITE else BLACK end
  end

  def current_points
    points = {
      WHITE => 0,
      BLACK => 0,
    }

    Game.includes(players: :pieces).find(self.id).players.map do |player|
      points[player.color] += player.get_points.values.sum
    end

    points
  end

  def create_player!
    points = self.current_points

    is_black = if points[WHITE] > points[BLACK]
      true
    elsif points[BLACK] > points[WHITE]
      false
    else
      [true, false].sample
    end

    self.players.create!(is_black: is_black, points: Player::STARTING_POINTS)
  end

  def first_square(board_x, board_y)
    self.location_to_square({ board_x: board_x, board_y: board_y, x: 0, y: 0 })
  end

  def empty_squares(board_x, board_y, pieces: nil)
    pieces ||= self.pieces_by_board[[board_x, board_y]]
    first_square = self.first_square(board_x, board_y)
    (first_square...first_square + 64).to_a - pieces.map(&:square)
  end

  def choose_starting_board(player:, count:)
    coords = []
    self.boards_tall.times do |board_y|
      self.boards_wide.times do |board_x|
        coords << [board_x, board_y]
      end
    end

    coords.shuffle.each do |board_x, board_y|
      pieces = self.pieces_by_board[[board_x, board_y]]
      if pieces.all? { |piece| piece.player.color == player.color }
        empty_squares = self.empty_squares(board_x, board_y, pieces: pieces)

        if empty_squares.length > count
          return [board_x, board_y]
        end
      end
    end

    return nil
  end

  if Rails.env.development?
    def reset
      Game.includes(players: { pieces: :moves })
        .find_by(id: self.id)
        .players
        .flat_map(&:pieces)
        .flat_map(&:moves)
        .map(&:destroy!)

      self.update!(current_turn: 0)
    end
  end

  def board_hash(value_type)
    h = {}

    self.boards_tall.times do |board_y|
      self.boards_wide.times do |board_x|
        h[[board_x, board_y]] = {
          array: [],
          hash: {},
        }[value_type] || raise("game.board_hash: unknown value_type #{value_type}")
      end
    end

    h
  end

  def pieces_by_board
    @pieces_by_board ||= begin
      h = self.board_hash(:array)

      players.includes(:pieces).each do |player|
        player.pieces.each do |piece|
          location = self.square_to_location(piece.square)
          h[[location[:board_x], location[:board_y]]] << piece
        end
      end

      h
    end
  end

  # Each board is 64 consecutive indexes:
  # + - - - - - - - - + - - - - - - - - +
  # | 0 1 2 3 4 5 6 7 | 64 64 66 ...    |
  # | 8 9 ...         |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |    ... 61 62 63 |     ... 126 127 |
  # + - - - - - - - - + - - - - - - - - +
  # | 128 129 ...     |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # + - - - - - - - - + - - - - - - - - +
  def location_to_square(location)
    squares_per_board_row = self.boards_wide * 64

    (location[:board_y] * squares_per_board_row) +
      (location[:board_x] * 64) +
      (location[:y] * 8) +
      location[:x]
  end

  def square_to_location(square)
    squares_per_board_row = self.boards_wide * 64

    board_y = square / squares_per_board_row
    square %= squares_per_board_row

    board_x = square / 64
    square %= 64

    y = square / 8
    square %= 8

    x = square

    {
      board_x: board_x,
      board_y: board_y,
      x: x,
      y: y,
    }
  end

  def build_cache
    cache = {}

    all_pieces = Game.includes(players: { pieces: :moves }).find(self.id).players.flat_map(&:pieces)
    all_pieces.each do |piece|
      move = piece.current_move(self)
      intermediate_squares = if move
        move.get_intermediate_squares
      else
        [piece.square] * Move::INTERMEDIATE_SQUARES_PER_TURN
      end

      cache[piece.id] = {
        piece: piece,
        move: move,
        intermediate_squares: intermediate_squares,
      }
    end

    cache
  end

  def get_move_steps(cache)
    steps = {}

    bumped_pieces = Set.new
    captured_pieces = Set.new

    board_hash = self.board_hash(:array)

    Move::INTERMEDIATE_SQUARES_PER_TURN.times.map do |idx|
      board_hash.each.with_index do |((board_x, board_y), _), board_idx|
        steps[[board_x, board_y]] ||= []
        step = {}

        get_stage = -> (piece) do
          stage = Piece::Stage.new
          intermediate_squares = cache[piece.id][:intermediate_squares]
          current_square = intermediate_squares[idx]
          previous_square = idx > 0 && intermediate_squares[idx - 1]
          stage.target_square = current_square
          previous_square = if idx == 0
            piece.square
          else
            cache[piece.id][:intermediate_squares][idx - 1]
          end

          previous_location = self.square_to_location(previous_square)
          stage.original_board = [previous_location[:board_x], previous_location[:board_y]]

          if captured_pieces.include?(piece.id)
            stage.kind = :captured
          else
            if piece.square == current_square
              stage.kind = :initial
            elsif idx > 0 && current_square == previous_square
              stage.kind = :moved
            else
              stage.is_array = true
              stage.kind = :moving
            end
          end

          stage
        end

        cache.each do |_piece_id, piece_cache|
          piece = piece_cache[:piece]
          current_square = piece_cache[:intermediate_squares][idx]
          current_location = self.square_to_location(current_square)

          if current_location[:board_x] == board_x && current_location[:board_y] == board_y
            piece_stage = if bumped_pieces.include?(piece.id)
              original_piece_location = self.square_to_location(piece.square)
              original_board_x, original_board_y = [original_piece_location[:board_x], original_piece_location[:board_y]]
              steps[[original_board_x, original_board_y]][idx] ||= {}
              steps[[original_board_x, original_board_y]][idx].merge!(piece.square => { bumped: piece.id })

              Piece::Stage.new(kind: :bumped, target_square: piece.square, original_board: [original_board_x, original_board_y])
            else
              get_stage.(piece)
            end
            step[piece_stage.target_square] ||= {}

            def changed_boards(stage)
              target_location = self.square_to_location(stage.target_square)
              original_board_x, original_board_y = [stage.original_board[0], stage.original_board[1]]

              original_board_x != target_location[:board_x] || stage.original_board[1] != target_location[:board_y]
            end

            if changed_boards(piece_stage)
              original_piece_location = self.square_to_location(piece.square)
              original_board_x, original_board_y = [original_piece_location[:board_x], original_piece_location[:board_y]]

              steps[[original_board_x, original_board_y]] ||= []
              steps[[original_board_x, original_board_y]][idx] ||= {}

              # `piece_stage.is_array` will always be true if changed_boards is true because the only way to change
              # boards is to be :moving (since :bumped is handled separately).
              steps[[original_board_x, original_board_y]][idx][piece_stage.target_square] ||= {}
              steps[[original_board_x, original_board_y]][idx][piece_stage.target_square][piece_stage.kind] ||= []
              steps[[original_board_x, original_board_y]][idx][piece_stage.target_square][piece_stage.kind] << piece.id
            end

            if piece_stage.is_array
              step[piece_stage.target_square][piece_stage.kind] ||= []
              step[piece_stage.target_square][piece_stage.kind] << piece.id
            else
              step[piece_stage.target_square][piece_stage.kind] = piece.id
            end

            step.each do |square, piece_steps|
              bump_moving_pieces = if piece_steps[:moving]
                if piece_steps[:moving].length > 1
                  # Many pieces arrived at the square at the same time.
                  true
                elsif piece_steps[:moving].length == 1
                  if piece_steps[:moved]
                    # Another piece already arrived at this square first.
                    true
                  elsif piece_steps[:initial]
                    moving_piece = cache[piece_steps[:moving].only!][:piece]
                    other_piece = cache[piece_steps[:initial]][:piece]

                    if other_piece.player.is_black == moving_piece.player.is_black
                      # Another piece was here and didn't move this turn.
                      true
                    else
                      if !captured_pieces.include?(other_piece.id)
                        # TODO Move this into apply_move_steps so all db updates happen there.
                        moving_piece.player.update!(
                          points: moving_piece.player.points + other_piece.points,
                        )
                        captured_pieces.add(other_piece.id)
                      end

                      false
                    end
                  end
                end
              end

              chain_bump = -> (piece_id) do
                chained_bump_square = cache[piece_id][:piece].square
                if chained_bump_piece_id = step[chained_bump_square] && step[chained_bump_square][:moved]
                  bumped_pieces.add(chained_bump_piece_id)
                  chain_bump.(chained_bump_piece_id)
                end
              end

              if bump_moving_pieces
                bumped_pieces.merge(piece_steps[:moving])
                piece_steps[:moving].each do |bumped_piece_id|
                  chain_bump.(bumped_piece_id)
                end
              end
            end
          end
        end

        # Need to merge here because when pieces move to adjacent boards up or left, they are added as :bumped before
        # the board_x/y iteration has happened.
        steps[[board_x, board_y]][idx] ||= {}
        steps[[board_x, board_y]][idx].merge!(step)
      end
    end

    steps
  end

  def process_current_moves
    self.update!(processing_moves: true)
    cache = self.build_cache
    steps = self.get_move_steps(cache)
    self.apply_move_steps(steps, cache)
    self.broadcast_move_steps(steps)
  ensure
    self.update!(processing_moves: false)
  end

  def broadcast_refresh(player)
    # This is updated here instead of in the ProcessMovesJob because the job runs before the piece moves are animated,
    # and that time should be considered part of the previous turn.
    self.update!(last_turn_completed_at: Time.now.utc)
    player.broadcast_boards
  end

  def get_boards_to_broadcast(player, steps_by_board)
    player_piece_ids = Set.new(player.pieces.map(&:id))

    steps_by_board.select do |(board_x, board_y), steps|
      piece_moves_on_board = steps.any? do |step|
        step.any? do |square, piece_steps|
          piece_steps.any? do |_, piece_ids|
            player_piece_ids.intersect?(Array.wrap(piece_ids))
          end
        end
      end
    end
  end

  def apply_move_steps(steps_by_board, cache)
    self.update!(current_turn: self.current_turn + 1)

    piece_ids_to_destroy = []

    steps_by_board.each do |_, steps|
      steps.last.each do |target_square, moves|
        if captured_piece_id = moves[:captured]
          piece_ids_to_destroy << captured_piece_id
        end

        if piece_id = moves[:moved]
          cached = cache[piece_id]
          move = cached[:move]
          piece = cached[:piece]

          if move.pending_spawn_kind
            spawned = piece.player.spawn_piece(square: piece.square, kind: move.pending_spawn_kind)
            steps.first[piece.square] = { spawned: spawned.kind }
          end
          piece.update!(square: target_square)
        end
      end
    end

    pieces_to_destroy = Piece.includes(:player).where(id: piece_ids_to_destroy)
    pieces_to_destroy.map(&:player).uniq.each do |player|
      killing_all_pieces = (player.pieces.map(&:id) - piece_ids_to_destroy).empty?

      if killing_all_pieces
        player.update!(status: DEAD)
      end
    end
    pieces_to_destroy.destroy_all
  end

  private

  def broadcast_move_steps(steps_by_board)
    self.players.each do |player|
      data = get_boards_to_broadcast(player, steps_by_board)

      broadcast_replace_to "player_#{player.id}_moves", target: 'game-moves', partial: "games/moves", locals: {
        data: data,
        player: player,
      }
    end
  end
end
