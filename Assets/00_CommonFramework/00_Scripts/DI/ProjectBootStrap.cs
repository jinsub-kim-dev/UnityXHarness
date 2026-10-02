using System.Collections;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Cysharp.Threading.Tasks;
using O2un.Manager;
using UnityEngine;
using VContainer.Unity;

namespace O2un.DI
{
    public interface IRootTask
    {
        UniTask WaitUntilReadyAsync();
    }

    public class ProjectBootStrap : IAsyncStartable
    {
        private readonly IEnumerable<IRootTask> _rootTasks;
        private readonly ISceneService _sceneService;

        public ProjectBootStrap(IEnumerable<IRootTask> rootTask, ISceneService sceneService)
        {
            _rootTasks = rootTask;
            _sceneService = sceneService;
        }

        public async UniTask StartAsync(CancellationToken cancellation = default)
        {
            Debug.Log("매니저 준비 시작");
            var waitTasks = _rootTasks.Select(manager => manager.WaitUntilReadyAsync());
            await UniTask.WhenAll(waitTasks);
            Debug.Log("매니저 준비 완료");

            await _sceneService.LoadSceneAsync(SCENE_NAME.GAME_SCENE);
        }
    }
}

