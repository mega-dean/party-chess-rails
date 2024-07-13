const grid = document.$('#board-grid');

const getGrid = () => document.$('#board-grid');

// If these aren't functions, they get defined on the games#index where there is no #board-grid element,
// so they are null/NaN.
// TODO Could probably fix this by not using eagerLoadControllersFrom.
export const utils = {
  grid: () => getGrid(),
  boardsWide: () => parseInt(getGrid()?.dataset.boardsWide),
  boardsTall: () => parseInt(getGrid()?.dataset.boardsTall),
  squareRem: () => 4,
  paddingRem: () => 0.6,
  postJson: (url, body) => {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

    return fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify(body),
    });
  },
  createImg: (color, kind, containerClass) => {
    const img = document.createElement("img");

    const findSrc = (kind) => {
      const img = [...document.$("#piece-images").$$(".piece-image")].find((img) => {
        return img.dataset.kind === kind && img.dataset.color === color;
      });

      return img?.src;
    };

    img.src = findSrc(kind);

    const container = document.createElement("div");
    container.classList.add(containerClass);
    container.appendChild(img);

    return { container, img };
  },
};
