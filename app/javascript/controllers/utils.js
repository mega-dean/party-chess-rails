const grid = document.$('#board-grid');

const getGrid = () => document.$('#board-grid');

// If these aren't functions, they get defined on the games#index where there is no #board-grid element,
// so they are null/NaN.
// TODO Could probably fix this by not using eagerLoadControllersFrom.
export const utils = {
  grid: () => getGrid(),
  boardsWide: () => parseInt(getGrid()?.dataset.boardsWide),
  boardsTall: () => parseInt(getGrid()?.dataset.boardsTall),
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
  }
};
