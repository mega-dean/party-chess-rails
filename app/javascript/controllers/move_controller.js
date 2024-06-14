import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number,
  }

  initialize() {
    this.selectedPieceId = null;
  }

  selectPiece() {
    this.selectedPieceId = this.idValue;
    var csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    let r = fetch(`/players/select_piece`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify({
        // TODO compare this to this.selectedPieceId to decide between select/deselect
        piece_id: this.idValue,
      })
    });
  }
};
