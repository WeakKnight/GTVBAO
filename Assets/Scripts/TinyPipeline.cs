using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RendererUtils;

public class TinyPipeline : RenderPipeline
{
    FrameData.Dict frameDataDict;
    private Material postProcessingMaterial;
    private ComputeShader ssaoShader;
    
    public TinyPipeline()
    {
        frameDataDict = new();
        Shader postProcessingShader = Shader.Find("Hidden/TinyPipeline/PostProcessing");
        postProcessingMaterial = new Material(postProcessingShader);

        ssaoShader = Resources.Load<ComputeShader>("SSAO");
    }

    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach (var camera in cameras)
        {
            if (camera != null)
            {
                RenderCamera(context, camera);
            }
        }
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);

        if (disposing)
        {
            frameDataDict.Release();
        }
    }
    
    void RenderCamera(ScriptableRenderContext context, Camera camera)
    {
        if (camera.cameraType == CameraType.Preview)
        {
            return;
        }

        FrameData frameData = frameDataDict.Get(camera);
        context.SetupCameraProperties(camera);
        if (!camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            return;
        }
        
        CullingResults cullingResults = context.Cull(ref p);
        
        var commandBuffer = new CommandBuffer { name = camera.name };
        
        RenderTargetBinding renderTargetBinding = new()
        {
            colorRenderTargets = new RenderTargetIdentifier[] { frameData.linearResult.colorBuffer, frameData.posW.colorBuffer, frameData.normalW.colorBuffer },
            depthRenderTarget = frameData.GetDepth(),
            colorLoadActions = new RenderBufferLoadAction[] { RenderBufferLoadAction.Load, RenderBufferLoadAction.Load, RenderBufferLoadAction.Load },
            colorStoreActions = new RenderBufferStoreAction[] { RenderBufferStoreAction.Store, RenderBufferStoreAction.Store, RenderBufferStoreAction.Store }
        };

        // Linear Color
        {
            commandBuffer.SetRenderTarget(renderTargetBinding);
            CameraClearFlags clearFlags = camera.clearFlags;
            commandBuffer.ClearRenderTarget(
                true,
                true,
                Color.clear
            );

            {
                commandBuffer.BeginSample("GBuffer");

                RendererListDesc desc = new RendererListDesc(new ShaderTagId("GBuffer"), cullingResults, camera)
                {
                    rendererConfiguration = PerObjectData.MotionVectors,
                    renderQueueRange = RenderQueueRange.opaque,
                    sortingCriteria = SortingCriteria.CommonOpaque,
                };

                RendererList rendererList = context.CreateRendererList(desc);
                commandBuffer.DrawRendererList(rendererList);
                commandBuffer.EndSample("GBuffer");
            }

            if (camera.clearFlags.HasFlag(CameraClearFlags.Skybox))
            {
                commandBuffer.BeginSample("Sky Rendering");
                RendererList skyRendererList = context.CreateSkyboxRendererList(camera);
                commandBuffer.DrawRendererList(skyRendererList);
                commandBuffer.EndSample("Sky Rendering");
            }
        }

        {
            commandBuffer.BeginSample("SSAO");
            Matrix4x4 projection = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);
            Matrix4x4 GetCameraToNormalizedNDCMatrix(int screenWidth, int screenHeight)
            {
                Matrix4x4 ndcToPixelMat = Matrix4x4.Translate(new Vector3(0.5f, 0.5f, 0)) *
                                          Matrix4x4.Scale(new Vector3(0.5f, 0.5f, 1));
                Matrix4x4 projectionToPixelMatrix = ndcToPixelMat * projection;
                return projectionToPixelMatrix;
            }
            var viewProjection = projection * camera.transform.worldToLocalMatrix;
            commandBuffer.SetGlobalTexture("_depth_texture", frameData.GetDepth(), RenderTextureSubElement.Depth);
            commandBuffer.SetGlobalTexture("_position_texture", frameData.posW);
            commandBuffer.SetGlobalTexture("_normal_texture", frameData.normalW);
            
            commandBuffer.SetGlobalVector("_camera_pixel_size_and_screen_size", new Vector4(1.0f / camera.pixelWidth, 1.0f / camera.pixelHeight, camera.pixelWidth, camera.pixelHeight));
            commandBuffer.SetGlobalMatrix("_view_projection_matrix", viewProjection);
            commandBuffer.SetGlobalMatrix("_projection_matrix", projection);
            commandBuffer.SetGlobalMatrix("_inverse_projection_matrix", projection.inverse);
            commandBuffer.SetGlobalMatrix("_world_to_camera_matrix", camera.worldToCameraMatrix);
            commandBuffer.SetGlobalMatrix("_camera_to_world_matrix", camera.cameraToWorldMatrix);
            commandBuffer.SetGlobalMatrix("_camera_to_normalized_ndc_matrix", GetCameraToNormalizedNDCMatrix(camera.pixelWidth, camera.pixelHeight));
            commandBuffer.SetGlobalVector("_camera_near_far", new Vector4(camera.nearClipPlane, camera.farClipPlane, 0.0f, 0.0f));
            
            commandBuffer.SetGlobalInt("frame_index", Time.renderedFrameCount);
            
            commandBuffer.SetComputeTextureParam(ssaoShader, 0, "_output_texture", frameData.ssaoTexture);
            commandBuffer.DispatchCompute(ssaoShader, 0, (camera.pixelWidth + 7) / 8, (camera.pixelHeight + 7) / 8, 1);
            commandBuffer.EndSample("SSAO");
        }
        
        {
            commandBuffer.BeginSample("Post Processing");
            commandBuffer.SetRenderTarget(frameData.cameraTexture);
            commandBuffer.SetGlobalTexture("_input_texture", frameData.linearResult);
            commandBuffer.SetGlobalTexture("_ao_texture", frameData.ssaoTexture);
            commandBuffer.DrawMesh(Utils.QuadMesh, Matrix4x4.identity, postProcessingMaterial);
            
            commandBuffer.EndSample("Post Processing");
        }
        
        context.ExecuteCommandBuffer(commandBuffer);
        commandBuffer.Release();
        
#if UNITY_EDITOR
        if (camera.cameraType == CameraType.SceneView)
        {
            context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
        }
#endif

        context.DrawUIOverlay(camera);

        context.Submit();
    }
}
