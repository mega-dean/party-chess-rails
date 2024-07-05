const grid = document.$('#board-grid');

export const utils = {
  grid,
  boardsWide: parseInt(grid.dataset.boardsWide),
  boardsTall: parseInt(grid.dataset.boardsTall),
};
