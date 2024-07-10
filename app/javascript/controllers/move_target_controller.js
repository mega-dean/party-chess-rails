import { Controller } from "@hotwired/stimulus"
import { utils } from "./utils"

export default class extends Controller {
  static values = {
    pieceId: Number,
    direction: String,
    boardX: Number,
    boardY: Number,
    x: Number,
    y: Number,
  }

  selectTarget() {
    const spawnKind = document.$('#spawn-pieces').$('.spawn-selected')?.dataset.kind;

    // This adjusts the location x/y values to be within the range [0..7]. The piece-controller allows them to be -1 or 8
    // for moves to adjacent boards, but the backend expects them to be within [0..7]. The `+ 8` is needed because
    // in js, `-1 % 8 === -1`.
    const adjust = (value) => ((value + 8) % 8);

    utils.postJson('/moves', {
      piece_id: this.pieceIdValue,
      x: adjust(this.xValue),
      y: adjust(this.yValue),
      board_x: this.boardXValue,
      board_y: this.boardYValue,
      direction: this.directionValue,
      spawn_kind: spawnKind,
    });
  }
};
