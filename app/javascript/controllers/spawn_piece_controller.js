import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button" ]

  clicked(event) {
    if (event.target.dataset.affordable) {
      this.buttonTargets.forEach((element) => {
        if (element.dataset.kind === event.target.dataset.kind) {
          let imgElement = element.getElementsByTagName("img")[0];
          if (imgElement.classList.contains("spawn-selected")) {
            imgElement.classList.remove("spawn-selected");
          } else {
            imgElement.classList.add("spawn-selected");
          }
        } else {
          let imgElement = element.getElementsByTagName("img")[0];
          imgElement.classList.remove("spawn-selected");
        }
      });
    }
  }

};
