using O2un.Camera;
using O2un.DataStore;
using UnityEngine;
using UnityEngine.InputSystem;
using VContainer;

public class GameManager : MonoBehaviour
{
    [Inject] private IUIWriter _ui;
    [Inject] private CameraManager _cameraManager;

    void Update()
    {
        if (Keyboard.current[Key.Space].wasPressedThisFrame)
        {
            _ui.Show(UIType.HUD);
        }

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
