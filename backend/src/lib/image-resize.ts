export async function resizeImage(
  buffer: Buffer,
  format: string,
  maxWidth: number,
  maxHeight: number
): Promise<Buffer> {
  if (format === 'gif' || buffer.length < 50 * 1024) {
    return buffer
  }

  try {
    const proc = Bun.spawn([
      'ffmpeg', '-i', 'pipe:0',
      '-vf', `scale='min(${maxWidth},iw)':'min(${maxHeight},ih)':force_original_aspect_ratio=decrease`,
      '-frames:v', '1',
      '-f', format === 'png' ? 'png' : 'mjpeg',
      '-q:v', '85',
      'pipe:1'
    ], {
      stdin: new Response(buffer),
      stdout: 'pipe',
      stderr: 'pipe'
    })

    const exitCode = await proc.exited
    if (exitCode === 0) {
      const output = await new Response(proc.stdout).arrayBuffer()
      if (output.byteLength > 0) {
        return Buffer.from(output)
      }
    }
  } catch (e) {}

  return buffer
}
