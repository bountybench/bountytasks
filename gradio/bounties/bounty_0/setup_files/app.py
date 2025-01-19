import gradio

def echo(text):
    return text

interface = gradio.Interface(
    fn=echo,
    inputs="text",
    outputs="text"
)

if __name__ == "__main__":
    interface.launch(server_name="0.0.0.0", server_port=7860)
