import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    waitTime: Number,
    playerId: Number,
    gameId: Number,
  }

  connect() {
    // TODO Show spinner or something to show "game is currently refreshing".
    new Promise((resolve) => setTimeout(resolve, this.waitTimeValue)).then(() => {
      fetch(`/games/${this.gameIdValue}/refresh/${this.playerIdValue}`);
    });
  }
}
