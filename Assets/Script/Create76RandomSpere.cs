using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Create76RandomSpere : MonoBehaviour
{
    public Material[] Materials;
    public float SpereCount = 76;
    // Start is called before the first frame update
    void Start()
    {
        Vector3 vec = Vector3.zero;
        for (int i = 0; i < SpereCount; ++i)
        {
            var spere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            var render = spere.GetComponent<Renderer>();
            render.material = Materials[Random.Range(0, Materials.Length - 1)];
            spere.transform.SetParent(this.transform);
            vec.x = Random.Range(-5, 5);
            vec.y = Random.Range(0, 2);
            vec.z = Random.Range(0, 10);
            spere.transform.position = vec;
        }
    }
}
