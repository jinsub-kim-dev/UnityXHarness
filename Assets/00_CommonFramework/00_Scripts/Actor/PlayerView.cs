using O2un.Input;
using UnityEngine;
using VContainer;

namespace O2un.Actor
{
    public class PlayerView : MonoBehaviour
    {
        private Vector3 _moveDir;
        // private float _verticalSpeed;
        // private bool _isGrounded = true;

        public void SetVelocity(Vector3 v)
        {
            _moveDir = v;
        }

        private void FixedUpdate()
        {
            transform.Translate(_moveDir * Time.fixedDeltaTime);
        }
    }
}