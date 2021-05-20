import os
import json
import pytest

from test_class import remoteTableClass


class context():
    def __init__(self):
        self.context_arr = {}

    def append(self, context_id, todo_id):
        self.context_arr[context_id] = todo_id

    def getItem(self, context_id=None):
        if context_id is None:
            return self.context_arr
        else:
            return self.context_arr[context_id]

    def print(self):
        print(self.context_arr)


context_class = context()


@pytest.mark.parametrize(
    "context_id, todo_text, todo_expected_code, todo_expected_text", [
        (0, 'Este es el primer texto', 200, "Este es el primer texto"),
        (1, 'Este es el segundo texto', 200, "Este es el segundo texto"),
        (2, None, 500, "Este esta mal")
    ])
def test_create(context_id, todo_text, todo_expected_code, todo_expected_text):
    if todo_text:
        create_text = {'text': todo_text}
    else:
        create_text = {}

    var_test_create = remoteTableClass().launchEvent(
        os.environ["ENDPOINT_URL"], 'create', json.dumps(create_text))
    assert var_test_create['statusCode'] == todo_expected_code

    text_return = json.loads(var_test_create['body'])
    if 'Items' in text_return:
        text_return = json.loads(text_return['Items'])

    if 'errorMsg' in text_return:
        text_return = text_return['errorMsg']

    if 'text' in text_return:
        todo_id = text_return['id']
        text_return = text_return['text']
        context_class.append(context_id, todo_id)

    assert text_return == todo_expected_text


@pytest.mark.parametrize("todo_expected_code, todo_expected_text", [
    (200, 'Este es el primer texto'),
    (200, 'Este es el segundo texto')
])
def test_list(todo_expected_code, todo_expected_text):
    var_test_list = remoteTableClass().launchEvent(
        os.environ["ENDPOINT_URL"], 'list')
    assert len(var_test_list) > 0

    text_return = json.loads(var_test_list['body'])
    if 'Items' in text_return:
        text_return = json.loads(text_return['Items'])

    arrResult = []
    if 'errorMsg' in text_return:
        text_return = text_return['errorMsg']

    for item in text_return:
        if 'text' in item:
            print(item['text'])
            arrResult.append(item['text'])

    assert todo_expected_text in arrResult


@pytest.mark.parametrize("context_id, todo_expected_text", [
    (0, 'Este es el primer texto'),
    (1, 'Este es el segundo texto')
])
def test_get(context_id, todo_expected_text):
    todo_id = context_class.getItem(context_id)
    var_test_get = remoteTableClass().launchEvent(
        os.environ["ENDPOINT_URL"] + "/" + todo_id, 'get')

    text_return = json.loads(var_test_get['body'])
    if 'Items' in text_return:
        text_return = json.loads(text_return['Items'])

    if 'errorMsg' in text_return:
        text_return = text_return['errorMsg']

    if 'text' in text_return:
        text_return = text_return['text']

    assert text_return == todo_expected_text


@pytest.mark.parametrize("context_id, target_language, todo_expected_text", [
    (0, 'en', 'This is the first text'),
    (0, 'fr', 'Ceci est le premier texte'),
    (0, 'it', 'Questo \u00e8 il primo testo'),
    (1, 'en', 'This is the second text'),
    (1, 'fr', 'Ceci est le deuxi\u00e8me texte')
])
def test_translate(context_id, target_language, todo_expected_text):
    todo_id = context_class.getItem(context_id)
    var_test_translate = remoteTableClass().launchEvent(
        os.environ["ENDPOINT_URL"] +
        "/" +
        todo_id +
        "/" +
        target_language, 'translate')

    text_return = json.loads(var_test_translate['body'])
    if 'Items' in text_return:
        text_return = json.loads(text_return['Items'])

    if 'errorMsg' in text_return:
        text_return = text_return['errorMsg']

    if 'TranslatedText' in text_return:
        text_return = text_return['TranslatedText']

    assert text_return == todo_expected_text


@pytest.mark.parametrize(
    "context_id, todo_text, \
    todo_checked, todo_expected_code, \
    todo_expected_text", [
        (0, 'Este es el primer texto modificado',
            True, 200,
            'Este es el primer texto modificado'),
        (1, 'Este es el segundo texto modificado',
            False, 200,
            'Este es el segundo texto modificado')
    ])
def test_update(
    context_id, todo_text, todo_checked,
        todo_expected_code, todo_expected_text):
    todo_id = context_class.getItem(context_id)
    update_text = {
        'text': todo_text,
        'checked': todo_checked
    }
    var_test_update = remoteTableClass().launchEvent(
        os.environ["ENDPOINT_URL"] +
        "/" +
        todo_id, 'update', json.dumps(update_text))
    assert var_test_update['statusCode'] == todo_expected_code

    text_return = json.loads(var_test_update['body'])
    if 'Items' in text_return:
        text_return = json.loads(text_return['Items'])

    if 'errorMsg' in text_return:
        text_return = text_return['errorMsg']

    if 'text' in text_return:
        todo_id = text_return['id']
        text_return = text_return['text']
        context_class.append(context_id, todo_id)

    assert text_return == todo_expected_text


@pytest.mark.parametrize(
    "context_id, todo_expected_code, todo_expected_text", [
        (0, 200, 'Todo deleted successfully'),
        (1, 200, 'Todo deleted successfully')
    ])
def test_delete(context_id, todo_expected_code, todo_expected_text):
    todo_id = context_class.getItem(context_id)

    var_test_delete = remoteTableClass().launchEvent(
        os.environ["ENDPOINT_URL"] + "/" + todo_id, 'delete')
    assert var_test_delete['statusCode'] == todo_expected_code

    text_return = json.loads(var_test_delete['body'])
    if 'Items' in text_return:
        text_return = json.loads(text_return['Items'])

    if 'errorMsg' in text_return:
        text_return = text_return['errorMsg']

    assert text_return == todo_expected_text