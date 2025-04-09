import { Hono } from 'hono'
import { data } from './data'

const app = new Hono()


app.get('/flows/:native/:target', (c) => {
  const target = data.filter((item) => item.parentId == null).map(e => {
    return {
      ...e,
      content: undefined,
    };
  });


  return c.json({
    flows: target
  })
})


app.get('/flow/:id', (c) => {
  const flow = data.find((item) => item.id === c.req.param().id)

  return c.json({
    flow: {
      ...flow,
      content: undefined,
    }
  });
})


app.get('/flows/:rootId', (c) => {
  const flows = data.filter((item) => item.parentId === c.req.param().rootId).map(e => {
    return {
      ...e,
      content: undefined,
    };
  });

  return c.json({ flows });

})

app.get('/words/:flowId', (c) => {
  const words = data.find((item) => item.id === c.req.param().flowId)?.content ?? []

  for (let i = 0; i < words.length; i++) {
    (words[i] as any).id = `${words[i].word}-${i}-${c.req.param().flowId}`;
  }

  for (let i = words.length - 1; i > 0; i--) {
    const word = words[i];
    (words[i] as any).previousCard = (words[i - 1] as any).id ?? null;
  }

  return c.json({ words });

})


export default app
