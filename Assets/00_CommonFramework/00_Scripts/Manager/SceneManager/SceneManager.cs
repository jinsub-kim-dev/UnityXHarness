using System;
using Cysharp.Threading.Tasks;
using O2un.UI;
using R3;
using UnityEngine;

namespace O2un.Manager
{
    public interface ISceneService
    {
        UniTask LoadSceneAsync(string sceneName);
    }

    public static class SCENE_NAME
    {
        public const string LOADING_SCENE = "Loading";
        public const string GAME_SCENE = "GameScene";
    }

    public sealed class SceneManager : ISceneService, ILoadingSource, IDisposable
    {
        public enum SceneState
        {
            Idle,
            TransitionToLoading,
            LoadingTarget,
            TransitionToTarget,
        }

        private readonly ReactiveProperty<SceneState> _currentState = new(SceneState.Idle);
        private readonly ReactiveProperty<float> _loadingProgress = new(0f);

        public ReadOnlyReactiveProperty<SceneState> CurrentState => _currentState;
        public ReadOnlyReactiveProperty<float> LoadingProgress => _loadingProgress;


        public void Dispose()
        {
            _currentState.Dispose();
            _loadingProgress.Dispose();
        }

        public async UniTask LoadSceneAsync(string sceneName)
        {
            if(SceneState.Idle != _currentState.Value)
            {
                return;
            }

            try
            {
                _currentState.Value = SceneState.TransitionToLoading;
                _loadingProgress.Value = 0;

                await UnityEngine.SceneManagement.SceneManager.LoadSceneAsync(SCENE_NAME.LOADING_SCENE, UnityEngine.SceneManagement.LoadSceneMode.Single);
                _currentState.Value = SceneState.LoadingTarget;

                var loadOp = UnityEngine.SceneManagement.SceneManager.LoadSceneAsync(sceneName, UnityEngine.SceneManagement.LoadSceneMode.Single);
                loadOp.allowSceneActivation = false; // 바로 전환되지 않고 처리를 기다림

                while(loadOp.progress < 0.9f)
                {
                    _loadingProgress.Value = loadOp.progress;
                    await UniTask.Yield(PlayerLoopTiming.Update);
                    
                    // 테스트를 위해 딜레이 추가
                    await UniTask.Delay(1000);
                }

                _loadingProgress.Value = 1f;
                _currentState.Value = SceneState.TransitionToTarget;

                loadOp.allowSceneActivation = true; // 실제 게임 씬으로 넘어가는 순간

                await loadOp;
            }
            finally
            {
                _currentState.Value = SceneState.Idle;
                _loadingProgress.Value = 0;
            }
        }
    }
}