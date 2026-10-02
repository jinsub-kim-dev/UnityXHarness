using Unity.Cinemachine;
using UnityEngine;

namespace O2un.Camera
{
    public sealed class CameraManager
    {
        private readonly CinemachineCamera _gamePlayerCamera;
        private readonly CinemachineCamera _cinematicCamera;

        public CameraManager(CinemachineCamera gamePlay, CinemachineCamera cinematic)
        {
            _gamePlayerCamera = gamePlay;
            _cinematicCamera = cinematic;
            
            _gamePlayerCamera.Priority = 10;
        }

        public void SetFollowTarget(Transform target)
        {
            _gamePlayerCamera.Follow = target; // 카메라가 따라가는 대상
            _gamePlayerCamera.LookAt = target; // 카메라가 바라보는 대상
        }

        public void SwitchToGamePlay() => _cinematicCamera.Priority = 0;
        public void SwitchToCinematic() => _cinematicCamera.Priority = 20;
        
    }
}
