using O2un.Camera;
using O2un.Input;
using Unity.Cinemachine;
using UnityEngine;
using VContainer;
using VContainer.Unity;

namespace O2un.DI
{
    public class GameSceneScope : LifetimeScope
    {
        [SerializeField] private CinemachineCamera _gamePlay;
        [SerializeField] private CinemachineCamera _cinematic;

        override protected void Configure(IContainerBuilder builder)
        {
            builder.Register<CameraManager>(Lifetime.Singleton)
                .WithParameter("gamePlay", _gamePlay)
                .WithParameter("cinematic", _cinematic);
        }
    }
}