import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number,
    selectedPieceId: Number,
    targetX: Number,
    targetY: Number,
  }

  selectPiece() {
    if (this.selectedPieceIdValue === this.idValue) {
      fetch(`/pieces/deselect`);
    } else {
      this.selectedPieceIdValue = this.idValue;
      fetch(`/pieces/${this.selectedPieceIdValue}/select`);
    }
  }

  selectTarget() {
    console.log(`selecting target ${this.targetXValue} ${this.targetYValue}`);
    // TODO Post move to backend.
    // - also need to unset selectedPiece, and remove all the target squares (which can be handled by a game_board
    //   broadcast from the /make_move route)
    // this.post_json('/players/select_piece', { piece_id: this.selectedPieceId });
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
