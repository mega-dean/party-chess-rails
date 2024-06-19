import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number,
    selectedPieceId: Number,
    targetX: Number,
    targetY: Number,
    targetBoardX: Number,
    targetBoardY: Number,
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
      target_x: this.targetXValue,
      target_y: this.targetYValue,
      target_board_x: this.targetBoardXValue,
      target_board_y: this.targetBoardYValue,
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
