import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number,
    selectedId: Number,
    targetSquare: Number,
    direction: String,
  }

  selectPiece() {
    if (document.$('#board-grid').dataset.movesAllowedNow) {
      if (this.selectedIdValue === this.idValue) {
        fetch(`/pieces/${this.selectedIdValue}/deselect`);
      } else {
        this.selectedIdValue = this.idValue;
        fetch(`/pieces/${this.selectedIdValue}/select`);
      }
    }
  }

  selectTarget() {
    let spawnKind = document.$('#spawn-pieces').$('.spawn-selected')[0]?.dataset.kind;

    this.postJson('/moves', {
      piece_id: this.selectedIdValue,
      target_square: this.targetSquareValue,
      direction: this.directionValue,
      spawn_kind: spawnKind,
    });
  }

  postJson(url, body) {
    var csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

    fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify(body),
    });
  }

};
