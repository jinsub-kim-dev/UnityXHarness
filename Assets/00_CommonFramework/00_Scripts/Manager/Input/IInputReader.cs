using UnityEngine;

namespace O2un.Input
{
    public interface IInputReader
    {
        Vector2 Move { get; }
        bool IsJumpPressed { get; }
    }
}
