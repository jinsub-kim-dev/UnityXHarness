using System;
using UnityEngine;
using UnityEngine.InputSystem;

namespace O2un.Input
{
    public class UIInputModule : GameInput.IUIActions, IDisposable
    {
        public void OnNewaction(InputAction.CallbackContext context)
        {
            throw new System.NotImplementedException();
        }

        public void Dispose()
        {
            // Implementation for disposal if needed
        }
    }
}