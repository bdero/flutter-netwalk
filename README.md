# netwalk

Netwalk, in Flutter.

## Building FlatBuffers

The board state is serialized using FlatBuffers. To regenerate the Dart code after modifying `lib/netwalk_board.fbs`:

1. Install `flatc` (the FlatBuffers compiler)
2. Run:
   ```bash
   ./build_flatbuffers.sh
   ```

Generated files are output to `lib/generated/`.
