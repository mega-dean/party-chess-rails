require "rails_helper"

RSpec.describe Player do
  before do
    @game = Game.create!(boards_wide: 10, boards_tall: 10, last_turn_completed_at: Time.now.utc)
    @player = @game.players.create!(is_black: false, points: Player::STARTING_POINTS)
  end

  describe "spawn_piece" do
    it "creates a piece with the given kind and square" do
      expect {
        @player.spawn_piece(square: 10, kind: BISHOP)
      }.to change { @player.reload.pieces.count }.from(0).to(1)

      created_piece = Piece.last
      expect(created_piece.square).to eq(10)
      expect(created_piece.kind).to eq(BISHOP)
    end

    it "deducts points and adds score" do
      expect {
        @player.spawn_piece(square: 10, kind: BISHOP)
      }.to change { @player.reload.score }.from(0).to(Piece.points(BISHOP))
        .and change { @player.reload.points }.from(Player::STARTING_POINTS).to(Player::STARTING_POINTS - Piece.cost(BISHOP))
    end
  end

  describe "create_starting_pieces!" do
    it "places pieces on empty squares on the given board_x/y" do
      ally_player = @game.players.create!(is_black: @player.is_black)
      (0..60).to_a.each do |square|
        ally_player.pieces.create!(kind: BISHOP, square: square)
      end

      @player.create_starting_pieces!(
        kinds: [KNIGHT, KNIGHT, KNIGHT],
        starting_board_x: 0,
        starting_board_y: 0,
      )

      expect(@player.pieces.map(&:square).sort).to eq([61, 62, 63])
    end

    it "raises an error when too many points are used" do
      expect {
        @player.create_starting_pieces!(
          kinds: [QUEEN, QUEEN, QUEEN],
          starting_board_x: 0,
          starting_board_y: 0,
        )
      }.to raise_error(Player::TooManyStartingPointsError)
    end

    it "raises an error when there are more pieces than empty squares" do
      ally_player = @game.players.create!(is_black: @player.is_black)
      (0..60).to_a.each do |square|
        ally_player.pieces.create!(kind: BISHOP, square: square)
      end

      expect {
        @player.create_starting_pieces!(
          kinds: [KNIGHT, KNIGHT, KNIGHT, KNIGHT],
          starting_board_x: 0,
          starting_board_y: 0,
        )
      }.to raise_error(Player::NotEnoughEmptySquaresError)
    end

    it "raises an error when an invalid kind is used" do
      expect {
        @player.create_starting_pieces!(
          kinds: ["something"],
          starting_board_x: 0,
          starting_board_y: 0,
        )
      }.to raise_error(Piece::InvalidKind)
    end

    it "raises an error when no kinds are passed in" do
      expect {
        @player.create_starting_pieces!(
          kinds: [],
          starting_board_x: 0,
          starting_board_y: 0,
        )
      }.to raise_error(Player::EmptyKindsError)
    end

    it "doesn't create any pieces when there is any error" do
      ally_player = @game.players.create!(is_black: @player.is_black)
      (0..60).to_a.each do |square|
        ally_player.pieces.create!(kind: BISHOP, square: square)
      end

      begin
        @player.create_starting_pieces!(
          kinds: [KNIGHT, KNIGHT, KNIGHT, KNIGHT],
          starting_board_x: 0,
          starting_board_y: 0,
        )
      rescue
      end

      expect(@player.pieces.count).to eq(0)
    end
  end

  describe "get_points" do
    specify ":on_board is the total cost of pieces in play" do
      @player.create_starting_pieces!(
        kinds: [KNIGHT, BISHOP, ROOK],
        starting_board_x: 0,
        starting_board_y: 0,
      )

      expect(@player.get_points[:on_board]).to eq(Piece.cost(KNIGHT) + Piece.cost(BISHOP) + Piece.cost(ROOK))
    end

    specify ":pending is the total cost of pieces that are going to be spawned next turn" do
      rook = @player.pieces.create!(kind: ROOK, square: 0)
      rook.try_move(target_square: 2, direction: :right, spawn_kind: KNIGHT)

      expect(@player.get_points[:pending]).to eq(Piece.cost(KNIGHT))
    end

    specify ":bank is the player's points, excluding :pending points" do
      rook = @player.pieces.create!(kind: ROOK, square: 0)
      rook.try_move(target_square: 2, direction: :right, spawn_kind: KNIGHT)

      expect(@player.get_points[:bank]).to eq(@player.points - Piece.cost(KNIGHT))
    end
  end
end
