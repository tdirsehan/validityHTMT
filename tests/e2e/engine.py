"""Exercise the installed module through jamovi's real HTTP/WebSocket server."""
import asyncio, json, math
from pathlib import Path
from tornado.httpclient import AsyncHTTPClient, HTTPRequest
from tornado.websocket import websocket_connect
from google.protobuf.json_format import MessageToDict
from jamovi.server import jamovi_pb2 as pb
from jamovi.server.options import write_value_to_pb

BASE='http://127.0.0.1:41337'
COOKIE='access_key=validityhtmt-ci-local-only'
OUT=Path('/work/artifacts')

async def main():
    http=AsyncHTTPClient()
    response=await http.fetch(HTTPRequest(BASE+'/open?filename=htmt_example.csv', method='POST', headers={'Cookie':COOKIE}, body=Path('/work/examples/htmt_example.csv').read_bytes(), request_timeout=60))
    messages=[json.loads(line) for line in response.body.decode().splitlines() if line.strip()]
    opened=messages[-1]
    assert opened['status']=='OK', opened
    instance=opened['url'].strip('/')
    ws=await websocket_connect(HTTPRequest(BASE.replace('http','ws')+'/'+instance+'/coms',headers={'Cookie':COOKIE}),connect_timeout=30)
    next_id=0
    async def send(request):
        nonlocal next_id
        next_id+=1
        envelope=pb.ComsMessage(id=next_id,instanceId=instance,payloadType=type(request).__name__,payload=request.SerializeToString())
        await ws.write_message(envelope.SerializeToString(),binary=True)
        return next_id
    async def receive():
        raw=await asyncio.wait_for(ws.read_message(),90)
        if raw is None:raise RuntimeError('jamovi closed the WebSocket')
        env=pb.ComsMessage();env.ParseFromString(raw)
        assert env.status!=pb.ERROR,(env.error.message,env.error.cause)
        body=getattr(pb,env.payloadType)() if env.payloadType else None
        if body is not None:body.ParseFromString(env.payload)
        return env,body
    await send(pb.InstanceRequest())
    while True:
        _,body=await receive()
        if isinstance(body,pb.InstanceResponse):break
    summaries=[]
    for index,(method,expected) in enumerate([
        ('pearson',[.204267526162471,.236232267231236,.267147172726584]),
        ('spearman',[.147178929330293,.222930886242476,.268662751866541])
    ],1):
        options={'correlation':method,'missing':'pairwise','threshold':'liberal90','showPairs':True}
        for n in range(1,9):
            options['c'+str(n)]=['C%d_%d'%(n,j) for j in range(1,5)] if n<=3 else []
            options['n'+str(n)]='Construct '+str(n)
        request=pb.AnalysisRequest(instanceId=instance,analysisId=index*2,name='discriminantValidity',ns='validityHTMT',perform=pb.AnalysisRequest.RUN,enabled=True)
        wrapped=pb.AnalysisOption();write_value_to_pb(options,wrapped);request.options.CopyFrom(wrapped.c)
        await send(request)
        while True:
            _,body=await receive()
            if not isinstance(body,pb.AnalysisResponse) or body.analysisId!=index*2:continue
            if body.error.message or body.status==pb.ANALYSIS_ERROR:raise RuntimeError(str(body))
            if body.status==pb.ANALYSIS_COMPLETE:break
        result=MessageToDict(body,preserving_proto_field_name=True)
        (OUT/(method+'-engine-result.json')).write_text(json.dumps(result,indent=2))
        tables={item.name:item for item in body.results.group.elements}
        assert not body.results.error.message,body.results.error.message
        pair=tables['pairTable']; assert not pair.error.message,pair.error.message
        columns={col.name:col for col in pair.table.columns}
        actual=[cell.d for cell in columns['htmt'].cells]
        assert len(actual)==3,actual
        assert all(math.isclose(a,b,rel_tol=0,abs_tol=1e-12) for a,b in zip(actual,expected)),(actual,expected)
        assert len(tables['htmtMatrix'].table.rowNames)==3
        summaries.append({'method':method,'expected':expected,'actual':actual,'status':'PASS'})
        print('PASS: actual jamovi engine',method,actual,flush=True)
    save_id=await send(pb.SaveRequest(filePath='/work/artifacts/validityHTMT_verified.omv',overwrite=True))
    while True:
        envelope,body=await receive()
        if envelope.id==save_id and isinstance(body,pb.SaveProgress) and envelope.status==pb.COMPLETE:
            assert body.success,str(body);break
    (OUT/'engine-summary.json').write_text(json.dumps({'instance':instance,'tests':summaries},indent=2))
    ws.close()
asyncio.run(main())
