import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    moveGeneration: Object,
    waitTime: Number,
  }

  connect() {
    new Promise((resolve) => setTimeout(resolve, this.waitTimeValue)).then(() => {
      for (let [targetSquare, moves] of Object.entries(this.moveGenerationValue)) {
        if (moves.captured) {
          document.getElementById(`piece-${moves.captured}`)?.remove();
        }
        let movedPieces = (moves.moving || []).concat(moves.bumped || []);
        movedPieces.forEach((pieceId) => {
          this.movePieceTo(pieceId, targetSquare);
        });
      }
    });

    [...document.getElementsByClassName('pending-move')].forEach((node) => node.remove());
  }

  movePieceTo(id, dest) {
    let piece = document.getElementById(`piece-${id}`);
    let relativeDestX = dest % 8;
    let relativeDestY = Math.floor((dest % 64) / 8);

    const squareRem = 4;
    const paddingRem = 0.6;
    const x = (squareRem * relativeDestX) + paddingRem;
    const y = (squareRem * relativeDestY) + paddingRem;

    piece.style.transform = `translate(${x}rem, ${y}rem)`;
  }
};
