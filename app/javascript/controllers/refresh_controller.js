import { Controller } from "@hotwired/stimulus"
import { utils } from "./utils"

export default class extends Controller {
  static values = {
    waitTime: Number,
    playerId: Number,
    gameId: Number,
  }

  connect() {
    this.dispatch("setRedLight");

    new Promise((resolve) => setTimeout(resolve, this.waitTimeValue)).then(() => {
      utils.postJson("/games/refresh", {
        game_id: this.gameIdValue,
        player_id: this.playerIdValue,
      });
    });
  }
}
