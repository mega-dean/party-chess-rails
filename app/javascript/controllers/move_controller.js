import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number,
    selectedPieceId: Number,
    targetSquare: Number,
    direction: String,
  }

  selectPiece() {
    if (document.$('#board-grid').dataset.movesAllowedNow) {
      if (this.selectedPieceIdValue === this.idValue) {
        fetch(`/pieces/${this.selectedPieceIdValue}/deselect`);
      } else {
        this.selectedPieceIdValue = this.idValue;
        fetch(`/pieces/${this.selectedPieceIdValue}/select`);
      }
    }
  }

  selectTarget() {
    this.postJson('/moves', {
      piece_id: this.selectedPieceIdValue,
      target_square: this.targetSquareValue,
      direction: this.directionValue,
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
