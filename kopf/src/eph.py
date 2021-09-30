import datetime
import functools
import time, random

import kopf, os, kubernetes, yaml, asyncio

import random
import kopf
import threading



@kopf.on.startup()
def configure(settings: kopf.OperatorSettings, **_):
        # Assuming that the configuration is done manually:
    settings.admission.server = kopf.WebhookServer(addr='0.0.0.0', host="ac.cnzhonglunnet.com",port=8080,
                                                   certfile="/src/5416300__cnzhonglunnet.com.pem",
                                                   pkeyfile="/src/5416300__cnzhonglunnet.com.key")
    settings.admission.managed = 'auto.kopf.dev'

@kopf.on.validate('ephemeralvolumeclaims')
def check_items(warnings: list[str],spec, **_):
    if not isinstance(spec.get('items', []), list):
        raise kopf.AdmissionError("items must be a list if present.")


@kopf.on.probe(id='now')
def get_current(**kwargs):
    return datetime.datetime.utcnow().isoformat()


@kopf.on.probe(id='random')
def get_random_value(**kwargs):
    return random.randint(0, 1_000_000)


@kopf.on.cleanup()
async def cleanup_fn(logger, **kwargs):
    print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^bye:")


@kopf.index('pods', labels={'app': 'nginx'})
def kube_pods(namespace, name, spec: kopf.Spec, body: kopf.Body, **_):
    return {(namespace, name): name}


'''
@kopf.timer('ephemeralvolumeclaims', interval=10.0)
def ping_kex(kube_pods: kopf.Index, spec, memo: kopf.Memo, logger, name, **kwargs):
    time.sleep(0.3)
    print("this timer: " + name)
    logger.info(f"the content from index ################################## ")
    deployment, *_ = kube_pods[('default', 'nginx')]
    actual = deployment.status.get('replicas')
    desired = deployment.spec.get('replicas')
    print(f'{deployment.meta.name}: {actual}/{desired}')
    return {'check': time.ctime()}


@kopf.on.event('ephemeralvolumeclaims')
def pingd(memo: kopf.Memo, **_):
    memo.counter = memo.get('counter', 0) + 1
'''


async def create_a(retry, name, **kwargs):
    print("*** create A has been done")


@kopf.on.create('ephemeralvolumeclaims', retries=10)
def create_fn(memo: kopf.Memo, body, resource, spec, name, retry, namespace, logger, **kwargs):
    kopf.event(body, type="SomeType", reason='SomeReason', message="some message ************")
    size = spec.get('size')
    memo.counter = memo.get('counter', 0) + 1

    if not size:
        raise kopf.PermanentError(f"Size must be set. Got {size!r}.")
    path = os.path.join(os.path.dirname(__file__), 'pvc.yaml')
    tmpl = open(path, 'rt').read()
    text = tmpl.format(size=size, name=name)
    data = yaml.safe_load(text)

    pod_manifest = {
        'apiVersion': 'v1',
        'kind': 'Pod',
        'metadata': {
            'name': name
        },
        'spec': {
            'containers': [{
                'image': 'busybox',
                'name': 'sleep',
                "args": [
                    "/bin/sh",
                    "-c",
                    "while true;do date;sleep 5; done"
                ]
            }]
        }
    }

    objs = [data, pod_manifest]
    # kopf.label(objs, {'place': 'jiangsu', 'company': 'urs'})
    print(objs)
    kopf.adopt(objs)

    api = kubernetes.client.CoreV1Api()
    obj = api.create_namespaced_persistent_volume_claim(namespace=namespace, body=data)
    objPod = api.create_namespaced_pod(namespace=namespace, body=pod_manifest)
    print("")
    # kopf.info(objPod.to_dict(), reason='someReason', message=f"this pod is create by {name}")
    logger.info(f'PVC child is created by james: ')

    print("..................................................")
    print(f" counter   {memo.counter}")
    print("..................................................")
    return {'pvc-name': obj.metadata.name, 'pod-name': objPod.metadata.name}


@kopf.on.update('ephemeralvolumeclaims')
def update_fn(memo: kopf.Memo, spec, patch, name, diff, status, namespace, logger, body, **kwargs):
    size = spec.get('size', None)
    memo.counter = memo.get('counter', 0) + 1
    if not size:
        raise kopf.PermanentError(f"Size must be set. Got {size!r}.")
    pvc_name = status['create_fn']['pvc-name']
    pvc_patch = {'spec': {
        'resources': {
            'requests': {
                'storage': size
            }
        }
    }}
    api = kubernetes.client.CoreV1Api()

    obj = api.patch_namespaced_persistent_volume_claim(
        namespace=namespace,
        name=pvc_name,
        body=pvc_patch
    )
    print(f" ^^^^^^^^^^^{memo.counter}  ^^^^^^^^^^ ")
    logger.info(f'xxxxxxxxxxxx diff object xxx: {name}')
    place = random.choice(["suzhou", "shanghai", "jiangsu"])
    print(f"daemon running for {patch}")
    print("-------------------------------------")
    patch.status['place'] = place + "  " + name
    print(f"daemon running for {patch}")


@kopf.on.resume('ephemeralvolumeclaims')
def my_handler(spec, name, **kwargs):
    print(f"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!{name}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")


@kopf.daemon('ephemeralvolumeclaims', initial_delay=10)
async def monitorEvc(patch, stopped, kube_pods: kopf.Index, body, status, spec, logger, name, **_):
    while True:
        await asyncio.sleep(10.0)



