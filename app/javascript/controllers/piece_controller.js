import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    moveGeneration: String,
    waitTime: Number,
  }

  connect() {
    new Promise((resolve) => setTimeout(resolve, this.waitTimeValue)).then(() => {
      const parsed = JSON.parse(this.moveGenerationValue);
      for (let [targetSquare, moves] of Object.entries(parsed)) {
        // CLEANUP
        let movedPieces = moves.bumped ?
                          (moves.moving || []).concat(moves.bumped)
                        : (moves.moving || []);
        movedPieces.forEach((pieceId) => {
          this.movePieceTo(pieceId, targetSquare);
        });
      }
    });

    [...document.getElementsByClassName('pending-move')].forEach((node) => node.remove());
  }

  movePieceTo(id, dest) {
    let piece = document.getElementById(`piece_${id}`);
    let relativeDestX = dest % 8;
    let relativeDestY = Math.floor((dest % 64) / 8);

    const squareRem = 4;
    const paddingRem = 0.6;
    const x = (squareRem * relativeDestX) + paddingRem;
    const y = (squareRem * relativeDestY) + paddingRem;

    piece.style.transform = `translate(${x}rem, ${y}rem)`;
  }
};
