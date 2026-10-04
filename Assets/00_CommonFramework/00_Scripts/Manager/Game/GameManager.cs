using System;
using Cysharp.Threading.Tasks;
using O2un.DataStore;
using O2un.Manager;
using R3;
using UnityEngine;
using VContainer.Unity;

namespace O2un.Game
{
    public sealed class GameManager : IGameFlow, IStartable, IDisposable
    {
        private readonly IPlayerDataReader _playerData;
        private readonly ISceneService _sceneService;

        private readonly ReactiveProperty<GameState> _state = new(GameState.Ready);
        private readonly CompositeDisposable _disposables = new();

        public ReadOnlyReactiveProperty<GameState> State => _state;

        public GameManager(IPlayerDataReader playerData, ISceneService sceneService)
        {
            _playerData = playerData;
            _sceneService = sceneService;
        }

        public void Start()
        {
            _playerData.CurrentHP.Subscribe(hp =>
            {
                if (hp <= 0)
                {
                    EndGame();
                }
            }).AddTo(_disposables);

            StartGame();
        }

        public void StartGame()
        {
            if (GameState.Ready != _state.Value)
            {
                return;
            }

            Time.timeScale = 1f;
            _state.Value = GameState.Playing;
        }

        public void Pause()
        {
            if (GameState.Playing != _state.Value)
            {
                return;
            }

            Time.timeScale = 0f;
            _state.Value = GameState.Paused;
        }

        public void Resume()
        {
            if (GameState.Paused != _state.Value)
            {
                return;
            }

            Time.timeScale = 1f;
            _state.Value = GameState.Playing;
        }

        public void Restart()
        {
            Time.timeScale = 1f;
            _sceneService.LoadSceneAsync(SCENE_NAME.GAME_SCENE).Forget();
        }

        private void EndGame()
        {
            if (GameState.Playing != _state.Value)
            {
                return;
            }

            Time.timeScale = 0f;
            _state.Value = GameState.GameOver;
        }

        public void Dispose()
        {
            Time.timeScale = 1f;
            _disposables.Dispose();
            _state.Dispose();
        }
    }
}
