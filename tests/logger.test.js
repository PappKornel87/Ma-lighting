const { log } = require('../src/utils/logger');

describe('Logger', () => {
  it('should log a message with a timestamp', () => {
    const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
    const message = 'Test message';
    log(message);
    expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringMatching(/\[.*\] Test message/));
    consoleLogSpy.mockRestore();
  });
});
