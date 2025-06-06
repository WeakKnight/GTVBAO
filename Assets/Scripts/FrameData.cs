﻿
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class FrameData
{
    public RenderTargetIdentifier cameraTexture;
    public RenderTexture linearResult;
    public RenderTexture posW;
    public RenderTexture normalW;
    public RenderTexture ssaoTexture;
    public int width = -1;
    public int height = -1;
    
    public RenderTargetIdentifier GetDepth()
    {
        return linearResult.depthBuffer;
    }
    
    private void Dispose()
    {
        if (linearResult)
        {
            linearResult.Release();
        }
        linearResult = null;
        
        if (normalW)
        {
            normalW.Release();
        }
        normalW = null;

        if (posW)
        {
            posW.Release();
        }
        posW = null;
        
        if (ssaoTexture)
        {
            ssaoTexture.Release();
        }
        ssaoTexture = null;
    }
    private void Resize(Camera camera)
    {
        if (width == camera.pixelWidth && height == camera.pixelHeight && linearResult != null && normalW != null && ssaoTexture != null)
        {
            return;
        }

        Dispose();

        width = camera.pixelWidth;
        height = camera.pixelHeight;

        linearResult = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 24, RenderTextureFormat.RGB111110Float, RenderTextureReadWrite.Linear);
        linearResult.Create();

        posW = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        posW.Create();
        
        normalW = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
        normalW.Create();
        
        ssaoTexture = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
        ssaoTexture.enableRandomWrite = true;
        ssaoTexture.filterMode = FilterMode.Point;
        ssaoTexture.Create();
    }
    
    public class Dict
    {
        Dictionary<Camera, FrameData> dics = new();
        
        public FrameData Get(Camera camera)
        {
            RenderTargetIdentifier GetCameraTexture()
            {
                if (camera.targetTexture)
                {
                    return camera.targetTexture;
                }

                return BuiltinRenderTextureType.CameraTarget;
            }
            
            if (!dics.TryGetValue(camera, out FrameData fbo))
            {
                fbo = new FrameData();
                dics[camera] = fbo;
            }

            fbo.cameraTexture = GetCameraTexture();

            fbo.Resize(camera);

            return fbo;
        }
        
        public void Release()
        {
            foreach (var fbo in dics)
            {
                fbo.Value.Dispose();
            }
            dics.Clear();
        }
    }
}