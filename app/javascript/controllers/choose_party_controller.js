import { Controller } from "@hotwired/stimulus"
import { utils } from "./utils"

export default class extends Controller {
  static targets = ["bank", "button", "chosen"]

  static values = {
    bank: Number,
    color: String,
    party: Array,
    url: String,
  }

  bankValueChanged() {
    this.bankTarget.innerHTML = this.bankValue;

    this.buttonTargets.forEach((element) => {
      if (parseInt(element.dataset.cost) <= this.bankValue) {
        element.dataset.affordable = 'yes';
        element.parentNode.classList.remove('not-affordable');
      } else {
        element.dataset.affordable = '';
        element.parentNode.classList.add('not-affordable');
      }
    });

    document.$("#join-button").disabled = (this.chosenTargets.length === 0);
  }

  removePiece(event) {
    const cost = event.params.cost;
    this.bankValue += cost;
    const parent = event.target.parentNode;
    parent.parentNode.removeChild(parent);
  }

  choosePiece(event) {
    if (event.target.dataset.affordable) {
      const { container, img } = utils.createImg(this.colorValue, event.target.dataset.kind, "chosen-piece-container");

      img.dataset.kind = event.target.dataset.kind;
      img.dataset.choosePartyTarget = "chosen";

      const removeButton = document.createElement("button");
      removeButton.classList.add("remove-button");
      removeButton.innerHTML = "remove";
      removeButton.dataset.action = "click->choose-party#removePiece";
      const cost = parseInt(event.target.dataset.cost);
      removeButton.dataset.choosePartyCostParam = cost;
      container.appendChild(removeButton);

      document.$('#current-party').appendChild(container);

      let hiddenField = document.$('#js-chosen-kinds');
      hiddenField.value = this.chosenTargets.map((target) => target.dataset.kind).join();

      this.bankValue -= cost;
    }
  }

};
