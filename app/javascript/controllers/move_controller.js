import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number,
    selectedPieceId: Number,
    targetIdx: Number,
  }

  selectPiece() {
    if (this.selectedPieceIdValue === this.idValue) {
      fetch(`/pieces/${this.selectedPieceIdValue}/deselect`);
    } else {
      this.selectedPieceIdValue = this.idValue;
      fetch(`/pieces/${this.selectedPieceIdValue}/select`);
    }
  }

  selectTarget() {
    this.post_json('/moves', {
      piece_id: this.selectedPieceIdValue,
      target_idx: this.targetIdxValue,
    });
  }

  post_json(url, body) {
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
