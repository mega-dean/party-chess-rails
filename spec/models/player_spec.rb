require "rails_helper"

RSpec.describe Player do
  before do
    @game = Game.create!(boards_wide: 10, boards_tall: 10, last_turn_completed_at: Time.now.utc)
    @player = @game.players.create!(is_black: true, points: 20)
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
        .and change { @player.reload.points }.from(20).to(20 - Piece.cost(BISHOP))
    end
  end
end
