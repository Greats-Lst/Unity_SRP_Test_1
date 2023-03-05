using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Create76RandomSpere : MonoBehaviour
{
    public Material[] Materials;
    public int SpereCount = 76;
    public int RandomColorCount = 24;

    private List<GameObject> m_gos = new List<GameObject>();
    // Start is called before the first frame update
    void Start()
    {
        m_gos.Clear();

        Vector3 vec = Vector3.zero;
        int rad_color_count = RandomColorCount;
        for (int i = 0; i < SpereCount; ++i)
        {
            var sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);

            // Set Material
            var render = sphere.GetComponent<Renderer>();
            render.material = Materials[Random.Range(0, Materials.Length)];
            sphere.transform.SetParent(this.transform);
            vec.x = Random.Range(-10f, 10f);
            vec.y = Random.Range(-8f, 5f);
            vec.z = Random.Range(6, 10);
            sphere.transform.localPosition = vec;

            if (rad_color_count-- > 0)
            {
                sphere.AddComponent<PerObjectMaterialProperties>();
                sphere.name = $"sphere{rad_color_count}";
            }

            m_gos.Add(sphere);
        }

        for (int i = 0; i < SpereCount; ++i)
        {
            var comp = m_gos[i].GetComponent<PerObjectMaterialProperties>();
            comp?.SetRandomColor();
        }
    }
}
