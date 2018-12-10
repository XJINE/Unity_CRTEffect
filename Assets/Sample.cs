using UnityEngine;

public class Sample : MonoBehaviour
{
    public float speed = 3;
    public Vector3 target;

    private void Start()
    {
        UpdateTarget();
    }

    void Update ()
    {
        if (this.transform.position != this.target)
        {
            this.transform.position = Vector3.MoveTowards(this.transform.position, this.target, Time.deltaTime * this.speed);
        }
        else
        {
            UpdateTarget();
        }
    }

    void UpdateTarget()
    {
        this.target = new Vector3(Random.Range(0, Screen.width),
                                  Random.Range(0, Screen.height),
                                  1);
        this.target = Camera.main.ScreenToWorldPoint(this.target);
        this.target.z = this.transform.position.z;
    }
}