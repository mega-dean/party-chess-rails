import { Controller } from "@hotwired/stimulus"
import { utils } from "./utils"

export default class extends Controller {
  static targets = [ "button" ]

  selectPiece(event) {
    if (utils.grid().dataset.movesAllowedNow && event.target.dataset.affordable) {
      this.buttonTargets.forEach((element) => {
        if (element.dataset.kind === event.target.dataset.kind) {
          if (element.classList.contains("spawn-selected")) {
            element.classList.remove("spawn-selected");
          } else {
            element.classList.add("spawn-selected");
          }
        } else {
          element.classList.remove("spawn-selected");
        }
      });
    }
  }

};
