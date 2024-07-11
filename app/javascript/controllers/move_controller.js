import { Controller } from "@hotwired/stimulus"
import { utils } from "./utils"

export default class extends Controller {
  static values = {
    step: Object,
    movesFromHiddenBoards: Array,
    waitTime: Number,
  }

  connect() {
    new Promise((resolve) => setTimeout(resolve, this.waitTimeValue)).then(() => {
      for (let [targetSquare, moves] of Object.entries(this.stepValue)) {
        if (moves.captured) {
          document.$(`#piece-${moves.captured}`)?.remove();
        }

        if (moves.spawned) {
          this.spawnPieceAt(targetSquare, moves.spawned);
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

  spawnPieceAt(targetSquare, kind) {
    // CLEANUP duplicated in choose_party_controller
    const img = document.createElement("img");

    const findSrc = (kind) => {
      const img = [...document.getElementsByTagName("img")].find((img) => {
        return img.dataset.kind === kind;
      });

      return img?.src;
    };

    img.src = findSrc(kind);
    img.classList.add("piece");

    const container = document.createElement("div");
    container.classList.add('piece-container');
    container.appendChild(img);

    const destBoard = this.getDestBoard(targetSquare);
    const translate = this.getTranslate(targetSquare, destBoard, destBoard);
    container.style.transform = translate;

    document.$(`#board-${destBoard.x}-${destBoard.y}`).appendChild(container);
    return container;
  }

  movePieceTo(id, dest) {
    const piece = document.$(`#piece-${id}`);

    // This check is needed now because the backend isn't broadcasting boards with move_steps.
    if (piece) {
      const srcBoard = {
        x: parseInt(piece.dataset.pieceBoardXValue),
        y: parseInt(piece.dataset.pieceBoardYValue),
      };

      const destBoard = this.getDestBoard(dest);
      const translate = this.getTranslate(dest, srcBoard, destBoard);
      piece.style.transform = translate;
    } else {
      // CLEANUP rename
      const targetSquare = dest;

      const movedPiece = this.movesFromHiddenBoardsValue.find((move) => {
        return move.id === id;
      });

      const destBoard = this.getDestBoard(targetSquare);

      const container = this.spawnPieceAt(targetSquare, movedPiece.kind);
      container.id = `piece-${movedPiece.id}`;

      // CLEANUP probably better to set .dataset on the element instead
      const regex = /(-?\d*\.?\d+)/g;
      const matches = container.style.transform.match(regex);
      const squareRem = 4;

      if (matches) {
        let x = parseFloat(matches[0]);
        let y = parseFloat(matches[1]);

        switch (movedPiece.direction) {
          case 'up':
            y += squareRem;
            break;
          case 'down':
            y -= squareRem;
            break;
          case 'left':
            x += squareRem;
            break;
          case 'right':
            x -= squareRem;
            break;
          case 'up_left':
            x += squareRem;
            y += squareRem;
            break;
          case 'up_right':
            x -= squareRem;
            y += squareRem;
            break;
          case 'down_left':
            x += squareRem;
            y -= squareRem;
            break;
          case 'down_right':
            x -= squareRem;
            y -= squareRem;
            break;
        }

        container.style.transform = `translate(${x}rem, ${y}rem)`;
      }

      // CLEANUP comment explaining this
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          container.style.transform = this.getTranslate(targetSquare, destBoard, destBoard);
        });
      });
    }
  }

  getDestBoard(destSquare) {
    const destBoardIdx = Math.floor(destSquare / 64);
    const destBoardX = destBoardIdx % utils.boardsWide();
    const destBoardY = Math.floor(destBoardIdx / utils.boardsWide());

    return { x: destBoardX, y: destBoardY };
  }

  getTranslate(destSquare, srcBoard, destBoard) {
    const relativeDestX = destSquare % 8;
    const relativeDestY = Math.floor((destSquare % 64) / 8);
    const squareRem = 4;
    const paddingRem = 0.6;

    const boardSize = (8 * squareRem) + (2 * paddingRem);
    const boardXOffset = (destBoard.x - srcBoard.x) * boardSize;
    const boardYOffset = (destBoard.y - srcBoard.y) * boardSize;

    const x = boardXOffset + (squareRem * relativeDestX) + paddingRem;
    const y = boardYOffset + (squareRem * relativeDestY) + paddingRem;

    if (isNaN(x) || isNaN(y)) {
      console.error(`NaN in getTranslate`);
      console.log(srcBoard);
      console.log(destBoard);
    }

    return `translate(${x}rem, ${y}rem)`;
  }
};
