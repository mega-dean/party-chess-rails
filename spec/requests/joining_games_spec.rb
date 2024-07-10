require "rails_helper"

RSpec.describe "Joining games", type: :request do
  context "when there is no current_player" do
    it "renders all games on a homepage" do
      get games_path
      expect(response).to be_ok
    end

    it "redirects other pages back to root" do
      get game_path(1)
      expect(response).to redirect_to(:root)

      get choose_party_path(1)
      expect(response).to redirect_to(:root)

      post join_game_path(1)
      expect(response).to redirect_to(:root)
    end
  end

  context "when there is a current_player" do
    before do
      @game = Game.create(boards_wide: 2, boards_tall: 2, last_turn_completed_at: Time.now.utc)

      post sessions_create_path({ game_id: @game.id })

      @player = @game.players.only!
    end

    context "player status is CHOOSING_PARTY" do
      it "redirects CHOOSING_PARTY players to the /choose-party page" do
        get games_path
        expect(response).to redirect_to(choose_party_path(@game.id))

        get game_path(@game.id)
        expect(response).to redirect_to(choose_party_path(@game.id))

        get choose_party_path(@game.id)
        expect(response).to be_ok
      end

      it "allows CHOOSING_PARTY players to join a game" do
        post join_game_path(@game.id), params: {
          chosen_kinds: "#{KNIGHT},#{BISHOP}",
        }

        expect(response).to redirect_to(game_path(@game.id))
        expect(@player.reload.status).to eq(JOINING)
        expect(@player.pieces.count).to eq(2)
      end

      context "trying to join a game with too many starting points" do
        it "redirects back to /choose-party" do
          post join_game_path(@game.id), params: {
            chosen_kinds: "#{QUEEN},#{QUEEN},#{QUEEN},#{QUEEN},#{QUEEN},#{QUEEN}",
          }

          expect(response).to redirect_to(choose_party_path(@game.id))
          expect(@player.reload.status).to eq(CHOOSING_PARTY)
          expect(@player.pieces.count).to eq(0)
        end
      end

      context "trying to join a game with invalid piece kinds" do
        it "redirects back to /choose-party" do
          post join_game_path(@game.id), params: {
            chosen_kinds: "bogus",
          }

          expect(response).to redirect_to(choose_party_path(@game.id))
          expect(@player.reload.status).to eq(CHOOSING_PARTY)
          expect(@player.pieces.count).to eq(0)
        end
      end
    end

    it "redirects JOINING players to the game page" do
      @player.update!(status: JOINING)

      get games_path
      expect(response).to redirect_to(game_path(@game.id))

      get choose_party_path(@game.id)
      expect(response).to redirect_to(game_path(@game.id))

      post join_game_path(@game.id)
      expect(response).to redirect_to(game_path(@game.id))

      get game_path(@game.id)
      expect(response).to be_ok
    end

    it "redirects PLAYING players to the game page" do
      @player.update!(status: PLAYING)

      get games_path
      expect(response).to redirect_to(game_path(@game.id))

      get choose_party_path(@game.id)
      expect(response).to redirect_to(game_path(@game.id))

      post join_game_path(@game.id)
      expect(response).to redirect_to(game_path(@game.id))

      get game_path(@game.id)
      expect(response).to be_ok
    end
  end
end
