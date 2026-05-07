export const password = {
  /**
   * Hashes a password using Argon2id
   */
  hash: async (plain: string): Promise<string> => {
    return Bun.password.hash(plain, {
      algorithm: "argon2id",
      memoryCost: 4 * 1024,
      timeCost: 3,
    });
  },

  /**
   * Verifies a plain password against a hash
   */
  verify: async (plain: string, hash: string): Promise<boolean> => {
    return Bun.password.verify(plain, hash);
  },
};
