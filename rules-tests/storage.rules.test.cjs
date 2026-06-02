const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { ref, uploadBytes } = require('firebase/storage');

const projectId = 'tantin-rules-test';
let testEnv;

jest.setTimeout(30000);

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({ projectId });
});

beforeEach(async () => {
  await testEnv.clearStorage();
});

afterAll(async () => {
  await testEnv.cleanup();
});

function storage(uid) {
  return uid === null
    ? testEnv.unauthenticatedContext().storage()
    : testEnv.authenticatedContext(uid).storage();
}

describe('profile avatar storage', () => {
  test('owner can upload an image avatar', async () => {
    await assertSucceeds(
      uploadBytes(
        ref(storage('payer'), 'users/payer/avatar.jpg'),
        new Uint8Array([1, 2, 3]),
        { contentType: 'image/jpeg' },
      ),
    );
  });

  test('another user cannot upload or write outside avatar path', async () => {
    await assertFails(
      uploadBytes(
        ref(storage('outsider'), 'users/payer/avatar.jpg'),
        new Uint8Array([1]),
        { contentType: 'image/jpeg' },
      ),
    );
    await assertFails(
      uploadBytes(
        ref(storage('payer'), 'avatars/payer.jpg'),
        new Uint8Array([1]),
        { contentType: 'image/jpeg' },
      ),
    );
  });

  test('owner cannot upload a non-image avatar', async () => {
    await assertFails(
      uploadBytes(
        ref(storage('payer'), 'users/payer/avatar.txt'),
        new Uint8Array([1]),
        { contentType: 'text/plain' },
      ),
    );
  });
});
