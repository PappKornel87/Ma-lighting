const { add } = require('../src/utils/mathUtils');

describe('Matematikai segédfüggvények', () => {
  test('az összeadásnak helyesnek kell lennie', () => {
    expect(add(2, 3)).toBe(5);
  });

  test('negatív számokkal is működnie kell', () => {
    expect(add(-1, -1)).toBe(-2);
  });
});
