using System.Collections.Generic;
using UnityEngine;

public static class Utils
{
    public static Mesh QuadMesh
    {
        get
        {
            if (_QuadMesh)
            {
                return _QuadMesh;
            }

            _QuadMesh = build_draw_quad_mesh(false);
            return _QuadMesh;
        }
    }
    private static Mesh _QuadMesh;
    
    private static Mesh build_draw_quad_mesh(bool flip)
    {
        List<Vector3> positions = new List<Vector3>();
        List<Vector2> texCoords = new List<Vector2>();
        for (int vertId = 0; vertId < 3; ++vertId)
        {
            /*
             * Draw a triangle like this, uv origin at left bottom (OpenGL style)
             * v0 _______ v2
             *   |     /
             *   |   /
             *   | /
             *   v1
             */
            Vector2 uv = new Vector2((vertId & 0x02) * 1.0f, (vertId & 0x01) * 2.0f);
            Vector3 p  = new Vector3(uv.x * 2 - 1, -uv.y * 2 + 1, 0);
            // Convert to OGL style uv coordinate convention
            if (!flip)
                uv.y = 1.0f - uv.y;

            // Apply OGL to Native API transform matrix since we will NOT apply it in shader
            Matrix4x4 m = GL.GetGPUProjectionMatrix(Matrix4x4.identity, true);
            p = m.MultiplyPoint(p);

            positions.Add(p);
            texCoords.Add(uv);
        }

        int[] indices = new int[3] {0, 1, 2};

        var mesh = new Mesh();
        mesh.SetVertices(positions);
        mesh.SetUVs(0, texCoords);
        mesh.SetIndices(indices, MeshTopology.Triangles, 0);
        
        return mesh;
    }
}