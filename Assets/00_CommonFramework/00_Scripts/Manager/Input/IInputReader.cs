using R3;
using UnityEngine;

namespace O2un.Input
{
    public interface IInputReader
    {
        ReadOnlyReactiveProperty<Vector2> Move { get; }
        Observable<Unit> IsJumpPressed { get; }
    }
}
