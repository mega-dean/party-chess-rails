import { Controller } from "@hotwired/stimulus"
import { utils } from "./utils"

export default class extends Controller {
  static values = {
    step: Object,
    currentColor: String,
    enemyColor: String,
    movesFromHiddenBoards: Array,
    waitTime: Number,
  }

  connect() {
    new Promise((resolve) => setTimeout(resolve, this.waitTimeValue)).then(() => {
      for (let [targetSquare, moves] of Object.entries(this.stepValue)) {
        if (moves.captured) {
          document.$(`#piece-${moves.captured}`)?.remove();
        }

        if (moves.spawnedKind) {
          this.spawnPieceAt(targetSquare, moves.spawnedKind, this.currentColorValue);
        }

        let movedPieces = (moves.moving || []).concat(moves.bumped || []);
        movedPieces.forEach((pieceId) => {
          this.movePieceTo(pieceId, parseInt(targetSquare));
        });
      }
    });

    [...document.$$('.pending-move')].forEach((node) => node.remove());
    utils.grid().removeAttribute('data-moves-allowed-now');
  }

  spawnPieceAt(targetSquare, kind, color, translateOffset = { x: 0, y: 0 }) {
    const { container, img } = utils.createImg(color, kind, "piece-container");

    img.classList.add("piece");

    const destBoard = this.getDestBoard(targetSquare);
    container.dataset.pieceBoardXValue = destBoard.x;
    container.dataset.pieceBoardYValue = destBoard.y;

    // Use destBoard for both args because a newly-spawned piece (or a piece moving from hidden board) will always
    // be on the targetSquare board.
    const translateCoords = this.getTranslateCoords(targetSquare, destBoard, destBoard);
    container.style.transform = this.getTranslateStyle({
      x: translateCoords.x + translateOffset.x,
      y: translateCoords.y + translateOffset.y,
    });

    document.$(`#board-${destBoard.x}-${destBoard.y}`).appendChild(container);
    return container;
  }

  movePieceTo(id, targetSquare) {
    const piece = document.$(`#piece-${id}`);

    // This check is needed now because the backend isn't broadcasting boards with move_steps.
    if (piece) {
      const srcBoard = {
        x: parseInt(piece.dataset.pieceBoardXValue),
        y: parseInt(piece.dataset.pieceBoardYValue),
      };

      const destBoard = this.getDestBoard(targetSquare);
      const translate = this.getTranslate(targetSquare, srcBoard, destBoard);
      piece.style.transform = translate;
    } else {
      const movedPiece = this.movesFromHiddenBoardsValue.find((move) => {
        return move.pieceId === id;
      });

      const squareRem = utils.squareRem();

      let translateOffset = { x: 0, y: 0 };
      switch (movedPiece.direction) {
        case 'up':
          translateOffset.y += squareRem;
          break;
        case 'down':
          translateOffset.y -= squareRem;
          break;
        case 'left':
          translateOffset.x += squareRem;
          break;
        case 'right':
          translateOffset.x -= squareRem;
          break;
        case 'up_left':
          translateOffset.x += squareRem;
          translateOffset.y += squareRem;
          break;
        case 'up_right':
          translateOffset.x -= squareRem;
          translateOffset.y += squareRem;
          break;
        case 'down_left':
          translateOffset.x += squareRem;
          translateOffset.y -= squareRem;
          break;
        case 'down_right':
          translateOffset.x -= squareRem;
          translateOffset.y -= squareRem;
          break;
      }

      const container = this.spawnPieceAt(targetSquare, movedPiece.kind, this.enemyColorValue, translateOffset);
      container.id = `piece-${movedPiece.pieceId}`;

      // When appending the container element with the original style.transform, and then immediately updating
      // style.transform, the piece was just being rendered at the final location because the browser wasn't
      // painting the DOM with the initial location. So these `requestAnimationFrame`s force the browser to repaint.
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          const destBoard = this.getDestBoard(targetSquare);
          container.style.transform = this.getTranslate(targetSquare, destBoard, destBoard);
        });
      });
    }
  }

  getDestBoard(destSquare) {
    const destBoardIdx = Math.floor(destSquare / 64);

    return {
      x: destBoardIdx % utils.boardsWide(),
      y: Math.floor(destBoardIdx / utils.boardsWide()),
    };
  }

  getTranslate(destSquare, srcBoard, destBoard) {
    const coords = this.getTranslateCoords(destSquare, srcBoard, destBoard);
    return this.getTranslateStyle(coords);
  }

  getTranslateStyle(coords) {
    return `translate(${coords.x}rem, ${coords.y}rem)`;
  }

  getTranslateCoords(destSquare, srcBoard, destBoard) {
    const relativeDestX = destSquare % 8;
    const relativeDestY = Math.floor((destSquare % 64) / 8);
    const squareRem = utils.squareRem();
    const paddingRem = utils.paddingRem()

    const boardSize = (8 * squareRem) + (2 * paddingRem);
    const boardXOffset = (destBoard.x - srcBoard.x) * boardSize;
    const boardYOffset = (destBoard.y - srcBoard.y) * boardSize;

    const x = boardXOffset + (squareRem * relativeDestX) + paddingRem;
    const y = boardYOffset + (squareRem * relativeDestY) + paddingRem;

    if (isNaN(x) || isNaN(y)) {
      console.error(`NaN in getTranslateCoords`);
      console.log(srcBoard);
      console.log(destBoard);
    }

    return { x, y };
  }
};
