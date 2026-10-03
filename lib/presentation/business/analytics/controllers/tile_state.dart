sealed class TileState<T> {
  const TileState();
}

class TileLoading<T> extends TileState<T> {
  const TileLoading();
}

class TileData<T> extends TileState<T> {
  final T data;
  const TileData(this.data);
}

class TileError<T> extends TileState<T> {
  final String message;
  const TileError(this.message);
}

class TileProLocked<T> extends TileState<T> {
  final String feature;
  const TileProLocked(this.feature);
}
