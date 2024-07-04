import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    step: Object,
    waitTime: Number,
  }

  connect() {
    new Promise((resolve) => setTimeout(resolve, this.waitTimeValue)).then(() => {
      for (let [targetSquare, moves] of Object.entries(this.stepValue)) {
        if (moves.captured) {
          document.$(`#piece-${moves.captured}`)?.remove();
        }
        let movedPieces = (moves.moving || []).concat(moves.bumped || []);
        movedPieces.forEach((pieceId) => {
          this.movePieceTo(pieceId, parseInt(targetSquare));
        });
      }
    });

    [...document.$('.pending-move')].forEach((node) => node.remove());
    document.$('#board-grid').removeAttribute('data-moves-allowed-now');
  }

  movePieceTo(id, dest) {
    const piece = document.$(`#piece-${id}`);
    const relativeDestX = dest % 8;
    const relativeDestY = Math.floor((dest % 64) / 8);

    // TODO This is duplicated in application_controller.rb.
    const squareRem = 4;
    const paddingRem = 0.6;
    const boardSize = (8 * squareRem) + (2 * paddingRem);

    const grid = document.$('#board-grid');
    const destBoardIdx = Math.floor(dest / 64);
    const destBoardX = destBoardIdx % parseInt(grid.dataset.boardsWide);
    const destBoardY = Math.floor(destBoardIdx / parseInt(grid.dataset.boardsWide));
    const boardXOffset = (destBoardX - parseInt(piece.dataset.boardX)) * boardSize;
    const boardYOffset = (destBoardY - parseInt(piece.dataset.boardY)) * boardSize;

    const x = boardXOffset + (squareRem * relativeDestX) + paddingRem;
    const y = boardYOffset + (squareRem * relativeDestY) + paddingRem;

    piece.style.transform = `translate(${x}rem, ${y}rem)`;
  }
};
