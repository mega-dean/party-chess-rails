import { Controller } from "@hotwired/stimulus"
import { utils } from "./utils"

export default class extends Controller {
  static values = {
    id: Number,
    isSelected: Boolean,
    kind: String,
    boardX: Number,
    boardY: Number,
    x: Number,
    y: Number,
  }

  deselect({ detail: { id }}) {
    if (id !== this.idValue) {
      this.isSelectedValue = false;
    }
  }

  selectPiece() {
    [...document.$$('.move-target')].forEach((node) => node.remove());

    if (utils.grid().dataset.movesAllowedNow) {
      if (this.isSelectedValue) {
        this.isSelectedValue = false;

        const hasPendingMove = [...document.$$('.pending-move')].find((pendingMove) => {
          return parseInt(pendingMove.dataset.pieceId) === this.idValue;
        });

        if (hasPendingMove) {
          fetch(`/pieces/${this.idValue}/deselect`);
        }
      } else {
        this.isSelectedValue = true;
        this.dispatch('deselect-other-pieces', { detail: { id: this.idValue }});

        // CLEANUP maybe don't use the term `location` since that is a browser built-in (ie a url)
        // This function expects locations that use -1 and 8 for x/y values for moves to adjacent boards.
        const makeTranslate = (location) => {
          const squareRem = 4;
          const paddingRem = 0.6;
          const boardGapSize = (2 * paddingRem);

          const boardXOffset = (location.boardX - this.boardXValue) * boardGapSize;
          const boardYOffset = (location.boardY - this.boardYValue) * boardGapSize;

          const x = boardXOffset + (squareRem * location.x) + paddingRem;
          const y = boardYOffset + (squareRem * location.y) + paddingRem;

          return `transform: translate(${x}rem, ${y}rem)`;
        };

        const makeMoveTarget = (direction, location) => {
          const child = document.createElement("div");
          child.classList.add("move-target");

          child.dataset.controller = "move-target";

          const setControllerValue = (name, value) => {
            child.dataset[`moveTarget${name}Value`] = value;
          };

          setControllerValue('PieceId', this.idValue);
          setControllerValue('Direction', direction);
          setControllerValue('BoardX', location.boardX);
          setControllerValue('BoardY', location.boardY);
          setControllerValue('X', location.x);
          setControllerValue('Y', location.y);

          child.dataset.action = "click->move-target#selectTarget";
          child.style = makeTranslate(location);

          return child;
        };

        const board = document.$(`#board-${this.boardXValue}-${this.boardYValue}`);
        const appendTargetLocations = (direction, locations) => {
          locations.forEach((location) => {
            const moveTarget = makeMoveTarget(direction, location);
            board.appendChild(moveTarget);
          });
        };

        const allTargetLocations = this.getTargetLocations();
        for (const [direction, targetLocations] of Object.entries(allTargetLocations)) {
          appendTargetLocations(direction, targetLocations);
        }
      }
    }
  }

  getKnightLocations() {
    let moves = {};

    const makeKey = (move) => {
      const horizontal = move.right ? `right${move.right}` : `left${move.left}`;
      const vertical = move.down ? `down${move.down}` : `up${move.up}`;

      return `${horizontal}${vertical}`;
    };

    const makeMove = (move) => {
      const dx = move.right ? move.right : -move.left;
      const dy = move.down ? move.down : -move.up;

      let dBoardX = 0;
      if (this.xValue + dx > 7) {
        dBoardX = 1;
      } else if (this.xValue + dx < 0) {
        dBoardX = -1;
      }

      let dBoardY = 0;
      if (this.yValue + dy > 7) {
        dBoardY = 1;
      } else if (this.yValue + dy < 0) {
        dBoardY = -1;
      }

      return {
        boardX: this.boardXValue + dBoardX,
        boardY: this.boardYValue + dBoardY,
        x: this.xValue + dx,
        y: this.yValue + dy,
      };
    }

    [
      { left: 2, up: 1 },
      { left: 1, up: 2 },
      { right: 2, up: 1 },
      { right: 1, up: 2 },
      { left: 2, down: 1 },
      { left: 1, down: 2 },
      { right: 2, down: 1 },
      { right: 1, down: 2 },
    ].forEach((move) => {
      moves[makeKey(move)] = [makeMove(move)];
    });

    return moves;
  }

  // CLEANUP "horizontal" isn't the opposite of "diagonal"
  getHorizontalLocations() {
    return {
      up: this.getLinearTargetLocations(this.yValue + 1, { y: -1 }),
      down: this.getLinearTargetLocations(8 - this.yValue, { y: 1 }),
      left: this.getLinearTargetLocations(this.xValue + 1, { x: -1 }),
      right: this.getLinearTargetLocations(8 - this.xValue, { x: 1 }),
    };
  }

  getDiagonalLocations() {
    const upLeftTargets = Math.min(this.xValue + 1, this.yValue + 1);
    const upRightTargets = Math.min(8 - this.xValue, this.yValue + 1);
    const downLeftTargets = Math.min(this.xValue + 1, 8 - this.yValue);
    const downRightTargets = Math.min(8 - this.xValue, 8 - this.yValue);

    return {
      up_left: this.getLinearTargetLocations(upLeftTargets, { x: -1, y: -1 }),
      up_right: this.getLinearTargetLocations(upRightTargets, { x: 1, y: -1 }),
      down_left: this.getLinearTargetLocations(downLeftTargets, { x: -1, y: 1 }),
      down_right: this.getLinearTargetLocations(downRightTargets, { x: 1, y: 1 }),
    };
  }

  getLinearTargetLocations(count, change) {
    const arr = Array.from({ length: count }, (_, idx) => idx);

    return arr.map((idx) => {
      const dx = change.x || 0;
      const dy = change.y || 0;

      let dBoardX = 0;
      let dBoardY = 0;

      // The count arg is "1 + (the number of squares in this direction on the current board)", so the last idx is a
      // move to an adjacent board.
      const isTargetingAdjacentBoard = idx === count - 1;

      if (isTargetingAdjacentBoard) {
        const horizontal = Object.keys(change).length === 1;

        if (horizontal) {
          dBoardX = dx;
          dBoardY = dy;
        } else {
          const x = this.xValue;
          const y = this.yValue;

          if (dx === 1) {
            if (dy === 1) {
              // down right
              if (x - y === 0) {
                dBoardX = 1;
                dBoardY = 1;
              } else if (x - y < 0) {
                dBoardX = 0;
                dBoardY = 1;
              } else {
                dBoardX = 1;
                dBoardY = 0;
              }
            } else {
              // up right
              if (x + y === 7) {
                dBoardX = 1;
                dBoardY = -1;
              } else if (x + y < 7) {
                dBoardX = 0;
                dBoardY = -1;
              } else {
                dBoardX = 1;
                dBoardY = 0;
              }
            }
          } else {
            if (dy === 1) {
              // down left
              if (x + y === 7) {
                dBoardX = -1;
                dBoardY = 1;
              } else if (x + y < 7) {
                dBoardX = -1;
                dBoardY = 0;
              } else {
                dBoardX = 0;
                dBoardY = 1;
              }
            } else {
              // up left
              if (x - y === 0) {
                dBoardX = -1;
                dBoardY = -1;
              } else if (x - y < 0) {
                dBoardX = -1;
                dBoardY = 0;
              } else {
                dBoardX = 0;
                dBoardY = -1;
              }
            }
          }
        }
      }

      return {
        boardX: this.boardXValue + dBoardX,
        boardY: this.boardYValue + dBoardY,
        x: this.xValue + (dx * (idx + 1)),
        y: this.yValue + (dy * (idx + 1)),
      };
    });
  }

  getTargetLocations() {
    let locations = [];

    if (this.kindValue === 'knight') {
      locations = this.getKnightLocations();
    } else if (this.kindValue === 'bishop') {
      locations = this.getDiagonalLocations();
    } else if (this.kindValue === 'rook') {
      locations = this.getHorizontalLocations();
    } else if (this.kindValue === 'queen') {
      locations = Object.assign(this.getHorizontalLocations(), this.getDiagonalLocations());
    } else {
      console.error(`invalid piece kind: '${this.kindValue}'`)
    }

    for (const [direction, targets] of Object.entries(locations)) {
      const filtered = targets.filter((target) => {
        return 0 <= target.boardX && target.boardX < utils.boardsWide() &&
               0 <= target.boardY && target.boardY < utils.boardsTall();
      });
      locations[direction] = filtered;
    }

    return locations;
  }

};
