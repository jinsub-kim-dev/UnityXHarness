using O2un.Camera;
using UnityEngine;
using UnityEngine.InputSystem;
using VContainer;

public class GameManager : MonoBehaviour
{
    [Inject] private CameraManager _cameraManager;

    void Update()
    {
        if (Keyboard.current[Key.F].wasPressedThisFrame)
        {
            _cameraManager.SwitchToGamePlay();
        }
        else if (Keyboard.current[Key.C].wasPressedThisFrame)
        {
            _cameraManager.SwitchToCinematic();
        }
    }
}
